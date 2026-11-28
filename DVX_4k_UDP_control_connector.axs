PROGRAM_NAME='DVX_4k_UDP_Control_connector'

//upload this to dvx using netlinx for connection to switcher
//requires creating a "workspace" and adding the device before the "source" code can be created
//check that program is running using telnet command "program info"
//tested on master FW v1.8.218, controller FW v1.1.50, switcher FW V2.0.4
//see troubleshooting guide for more help
//
// ---- UDP commands accepted on UDP_LISTEN_PORT ----
//   SYNC                 -> re-sends all routing state
//   EDID <n> <hex>       -> sets EDID on input n (1..MAX_INPUTS); <hex> = raw EDID as hex string
//   GETEDID <n>          -> requests EDID of input n (reply arrives as "RX IN<n> VIDIN_EDID_DATA-...")
//   anything else        -> passed straight to dvSw1 as a SEND_COMMAND (original behaviour)
//
// ---- Messages pushed to Node-RED (wire format: <SWITCHER_ID>|<message>\r\n) ----
//   ONLINE, HB, OUT<n> VIDEO <i>, OUT<n> AUDIO <i>, ACK ..., ERR ...,
//   RX IN<n> <text from switcher input port>   (e.g. VIDIN_EDID-4K60, VIDIN_PREF_EDID-...)
//
// NOTE: EDID command syntax per DVX-3266/2265-4K manual V1.1.8:
//   SEND_COMMAND <DEV>,"'VIDIN_EDID_DATA-<data>'"   and   "'?VIDIN_EDID_DATA'"
//   The switcher only replies VIDIN_EDID-/VIDIN_PREF_EDID- if the EDID is in AMX's recognised range.

DEFINE_DEVICE
dvUdp  = 0:2:0       // receives commands from Node-RED
dvPush = 0:3:0       // sends messages to Node-RED
dvSw1  = 5002:1:0    // switcher port 1 (video out 1 / audio group 1 / video in 1), also used to send commands
dvSw2  = 5002:2:0
dvSw3  = 5002:3:0
dvSw4  = 5002:4:0
dvSw5  = 5002:5:0    // input ports 5-8 (inputs only; NOT outputs)
dvSw6  = 5002:6:0
dvSw7  = 5002:7:0
dvSw8  = 5002:8:0

DEFINE_CONSTANT
CHAR    SWITCHER_ID[]    = 'xxxx'           // unique per switcher, 4 characters
INTEGER MAX_INPUTS       = 8                // 2265: 6   3266: 8
INTEGER MAX_OUTPUTS      = 4                // 2265: 2   3266: 4
CHAR    NODERED_IP[]     = '192.168.1.2'    // Node-RED host IP address
INTEGER NODERED_PORT     = 9000
INTEGER UDP_LISTEN_PORT  = 10001
INTEGER EDID_MIN_HEX     = 256              // 128-byte base EDID = 256 hex chars (assumption, loosen if needed)
INTEGER EDID_MAX_HEX     = 1024             // 512 bytes (base + 3 extension blocks)
INTEGER CMD_BUF_SIZE     = 1100

DEFINE_VARIABLE
// Output ports: used for routing feedback only. Port number = output number.
DEV dvSwAll[] = { dvSw1, dvSw2, dvSw3, dvSw4 }
// Input ports: index = input number. Used for EDID commands and replies.
DEV dvVidIn[] = { dvSw1, dvSw2, dvSw3, dvSw4, dvSw5, dvSw6, dvSw7, dvSw8 }

// Global (not STACK_VAR) because EDID strings are long
CHAR cCmd[1100]

// Every message to Node-RED goes through here, so the prefix is never forgotten.
// Wire format:  <SWITCHER_ID>|<message>\r\n
DEFINE_FUNCTION fnPush(CHAR cMsg[])
{
  SEND_STRING dvPush, "SWITCHER_ID, '|', cMsg, $0D, $0A"
}

DEFINE_FUNCTION fnSync()
{
  STACK_VAR INTEGER p
  STACK_VAR INTEGER c
  FOR (p = 1; p <= MAX_OUTPUTS; p++)
  {
    FOR (c = 30; c <= 36; c++)
      IF ([dvSwAll[p], c])
        fnPush("'OUT', ITOA(p), ' VIDEO ', ITOA(c - 30)")
    FOR (c = 40; c <= 46; c++)
      IF ([dvSwAll[p], c])
        fnPush("'OUT', ITOA(p), ' AUDIO ', ITOA(c - 40)")
  }
}

// Returns 1 if every character is 0-9, A-F or a-f
DEFINE_FUNCTION INTEGER fnIsHex(CHAR cStr[])
{
  STACK_VAR INTEGER i
  FOR (i = 1; i <= LENGTH_STRING(cStr); i++)
  {
    IF (!((cStr[i] >= '0' && cStr[i] <= '9') ||
          (cStr[i] >= 'A' && cStr[i] <= 'F') ||
          (cStr[i] >= 'a' && cStr[i] <= 'f')))
      RETURN 0
  }
  RETURN 1
}

DEFINE_START
WAIT 50
{
  IP_SERVER_OPEN(dvUdp.PORT, UDP_LISTEN_PORT, IP_UDP)
  IP_CLIENT_OPEN(dvPush.PORT, NODERED_IP, NODERED_PORT, IP_UDP)
  SEND_STRING 0, "SWITCHER_ID, ': UDP listener on ', ITOA(UDP_LISTEN_PORT)"
  WAIT 20
  {
    fnPush('ONLINE')      // tells Node-RED this switcher just started, so it can SYNC
  }
}

DEFINE_EVENT

// ---- Commands from Node-RED ----
DATA_EVENT[dvUdp]
{
  ONERROR:
  {
    SEND_STRING 0, "SWITCHER_ID, ': UDP error ', ITOA(DATA.NUMBER)"
  }
  STRING:
  {
    STACK_VAR INTEGER n
    STACK_VAR INTEGER nIn

    cCmd = DATA.TEXT
    n = LENGTH_STRING(cCmd)

    // trim trailing CR / LF / space
    WHILE (n > 0)
    {
      IF (cCmd[n] == $0D || cCmd[n] == $0A || cCmd[n] == $20)
      {
        n = n - 1
        SET_LENGTH_STRING(cCmd, n)
      }
      ELSE
      {
        BREAK
      }
    }

    IF (n > 0)
    {
      // don't log whole EDID strings to the console
      IF (n > 80)
        SEND_STRING 0, "SWITCHER_ID, ': UDP cmd: ', LEFT_STRING(cCmd, 40), '... (', ITOA(n), ' chars)'"
      ELSE
        SEND_STRING 0, "SWITCHER_ID, ': UDP cmd: ', cCmd"

      IF (UPPER_STRING(cCmd) == 'SYNC')
      {
        fnSync()
      }
      ELSE IF (LEFT_STRING(UPPER_STRING(cCmd), 5) == 'EDID ')
      {
        // EDID <n> <hex>
        REMOVE_STRING(cCmd, ' ', 1)          // drop "EDID "
        nIn = ATOI(cCmd)                     // input number
        REMOVE_STRING(cCmd, ' ', 1)          // drop "<n> ", leaving the hex string

        IF (nIn < 1 || nIn > MAX_INPUTS)
        {
          fnPush("'ERR EDID bad input ', ITOA(nIn)")
        }
        ELSE IF (LENGTH_STRING(cCmd) < EDID_MIN_HEX || LENGTH_STRING(cCmd) > EDID_MAX_HEX || (LENGTH_STRING(cCmd) % 2) != 0)
        {
          fnPush("'ERR EDID bad length ', ITOA(LENGTH_STRING(cCmd))")
        }
        ELSE IF (!fnIsHex(cCmd))
        {
          fnPush('ERR EDID non-hex characters')
        }
        ELSE
        {
          SEND_COMMAND dvVidIn[nIn], "'VIDIN_EDID_DATA-', cCmd"
          fnPush("'ACK EDID ', ITOA(nIn), ' len=', ITOA(LENGTH_STRING(cCmd))")
        }
      }
      ELSE IF (LEFT_STRING(UPPER_STRING(cCmd), 8) == 'GETEDID ')
      {
        // GETEDID <n>
        REMOVE_STRING(cCmd, ' ', 1)
        nIn = ATOI(cCmd)

        IF (nIn < 1 || nIn > MAX_INPUTS)
        {
          fnPush("'ERR GETEDID bad input ', ITOA(nIn)")
        }
        ELSE
        {
          SEND_COMMAND dvVidIn[nIn], '?VIDIN_EDID_DATA'
          fnPush("'ACK GETEDID ', ITOA(nIn)")
        }
      }
      ELSE
      {
        // original passthrough: anything else goes to dvSw1
        SEND_COMMAND dvSw1, cCmd
        fnPush("'ACK ', LEFT_STRING(cCmd, 60)")
      }
    }
  }
}

// ---- Push socket health ----
DATA_EVENT[dvPush]
{
  ONERROR:
  {
    SEND_STRING 0, "SWITCHER_ID, ': push error ', ITOA(DATA.NUMBER)"
    WAIT 50 { IP_CLIENT_OPEN(dvPush.PORT, NODERED_IP, NODERED_PORT, IP_UDP) }
  }
  OFFLINE:
  {
    SEND_STRING 0, "SWITCHER_ID, ': push offline'"
    WAIT 50 { IP_CLIENT_OPEN(dvPush.PORT, NODERED_IP, NODERED_PORT, IP_UDP) }
  }
}

// ---- Replies from the switcher input ports (e.g. VIDIN_EDID-4K60, VIDIN_PREF_EDID-..., VIDIN_EDID_DATA-...) ----
DATA_EVENT[dvVidIn]
{
  STRING:
  {
    fnPush("'RX IN', ITOA(DATA.DEVICE.PORT), ' ', DATA.TEXT")
  }
}

// ---- Routing feedback: port number = output number ----
CHANNEL_EVENT[dvSwAll, 0]
{
  ON:
  {
    STACK_VAR INTEGER nPort
    STACK_VAR INTEGER nCh
    nPort = CHANNEL.DEVICE.PORT
    nCh   = CHANNEL.CHANNEL

    IF (nCh >= 30 && nCh <= 36)
      fnPush("'OUT', ITOA(nPort), ' VIDEO ', ITOA(nCh - 30)")
    ELSE IF (nCh >= 40 && nCh <= 46)
      fnPush("'OUT', ITOA(nPort), ' AUDIO ', ITOA(nCh - 40)")
  }
}

DEFINE_PROGRAM
WAIT 600 'HEARTBEAT'      // every 60 s
{
  fnPush('HB')
}
