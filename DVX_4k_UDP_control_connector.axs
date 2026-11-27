PROGRAM_NAME='DVX_4k_UDP_Control_connector'

//upload this to dvx using netlinx for connection to switcher
//requires creating a "workspace" and adding the device before the "source" code can be created
//check that program is running using telnet command "program info"
//tested on master FW v1.8.218, controller FW v1.1.50, switcher FW V2.0.4
//see troubleshooting guide for more help


DEFINE_DEVICE
dvUdp  = 0:2:0       // receives commands from Node-RED
dvPush = 0:3:0       // sends messages to Node-RED
dvSw1  = 5002:1:0    // switcher port 1 (video out 1 / audio group 1), also used to send commands
dvSw2  = 5002:2:0
dvSw3  = 5002:3:0
dvSw4  = 5002:4:0

DEFINE_CONSTANT
CHAR    SWITCHER_ID[]    = 'xxxx'           // unique per switcher, 4 characters
INTEGER MAX_INPUTS    = 8                   // 2265: 6   3266: 8
INTEGER MAX_OUTPUTS   = 4                   // 2265: 2   3266: 4
CHAR    NODERED_IP[]     = '192.168.1.2'    // Node-RED host IP address
INTEGER NODERED_PORT     = 9000
INTEGER UDP_LISTEN_PORT  = 10001

DEFINE_VARIABLE
DEV dvSwAll[] = { dvSw1, dvSw2, dvSw3, dvSw4 }

// Every message to Node-RED goes through here, so the prefix is never forgotten.
// Wire format:  DVX1|<message>\r\n
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
    STACK_VAR CHAR cCmd[128]
    STACK_VAR INTEGER n

    cCmd = DATA.TEXT
    n = LENGTH_STRING(cCmd)
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
      SEND_STRING 0, "SWITCHER_ID, ': UDP cmd: ', cCmd"
      IF (UPPER_STRING(cCmd) == 'SYNC')
      {
        fnSync()
      }
      ELSE
      {
        SEND_COMMAND dvSw1, cCmd
        fnPush("'ACK ', cCmd")
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