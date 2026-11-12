PROGRAM_NAME='DVX_UDP_control_connector'

//upload this to dvx using netlinx for connection to switcher
//requires creating a "workspace" and adding the device before the "source" code can be created

DEFINE_DEVICE
dvUdp    = 0:2:0       // receives commands
dvPush   = 0:3:0       // sends status to Node-RED
dvSwitch = 5002:1:0
dvSw1 = 5002:1:0	// output channels
dvSw2 = 5002:2:0
dvSw3 = 5002:3:0
dvSw4 = 5002:4:0

DEFINE_CONSTANT
INTEGER UDP_LISTEN_PORT = 10001
CHAR    NODERED_IP[]    = '192.168.8.21'   // your Node-RED host
INTEGER NODERED_PORT    = 9000

DEFINE_VARIABLE
DEV dvSwAll[] = { dvSw1, dvSw2, dvSw3, dvSw4 }

DEFINE_FUNCTION fnSync()
{
  STACK_VAR INTEGER p
  STACK_VAR INTEGER c
  FOR (p = 1; p <= 4; p++)
  {
    FOR (c = 30; c <= 36; c++)
      IF ([dvSwAll[p], c])
        SEND_STRING dvPush, "'OUT', ITOA(p), ' VIDEO ', ITOA(c - 30), $0D, $0A"
    FOR (c = 40; c <= 46; c++)
      IF ([dvSwAll[p], c])
        SEND_STRING dvPush, "'OUT', ITOA(p), ' AUDIO ', ITOA(c - 40), $0D, $0A"
  }
}



DEFINE_START
WAIT 50
{
  IP_SERVER_OPEN(dvUdp.PORT, UDP_LISTEN_PORT, IP_UDP)
  IP_CLIENT_OPEN(dvPush.PORT, NODERED_IP, NODERED_PORT, IP_UDP)
  SEND_STRING 0, "'UDP listener on ', ITOA(UDP_LISTEN_PORT)"
}



DEFINE_EVENT


DATA_EVENT[dvUdp]
{
  ONERROR:
  {
    SEND_STRING 0, "'UDP error ', ITOA(DATA.NUMBER)"
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
      SEND_STRING 0, "'UDP cmd: ', cCmd"
	IF (UPPER_STRING(cCmd) == 'SYNC')
	    fnSync()
	ELSE
	    SEND_COMMAND dvSwitch, cCmd
      SEND_STRING dvPush, "'ACK ', cCmd, $0D, $0A"
    }
  }
}


CHANNEL_EVENT[dvSwAll, 0]
{
  ON:
  {
    STACK_VAR INTEGER nPort
    STACK_VAR INTEGER nCh
    nPort = CHANNEL.DEVICE.PORT
    nCh   = CHANNEL.CHANNEL

    IF (nCh >= 30 && nCh <= 36)
      SEND_STRING dvPush, "'OUT', ITOA(nPort), ' VIDEO ', ITOA(nCh - 30), $0D, $0A"
    ELSE IF (nCh >= 40 && nCh <= 46)
      SEND_STRING dvPush, "'OUT', ITOA(nPort), ' AUDIO ', ITOA(nCh - 40), $0D, $0A"
  }
}


/*
CHANNEL_EVENT[dvSwitch, 0]
{
  ON:
  {
    SEND_STRING 0,      "'CH ON  ', ITOA(CHANNEL.CHANNEL)"
    SEND_STRING dvPush, "'CH ON ', ITOA(CHANNEL.CHANNEL), $0D, $0A"
  }
  OFF:
  {
    SEND_STRING 0,      "'CH OFF ', ITOA(CHANNEL.CHANNEL)"
    SEND_STRING dvPush, "'CH OFF ', ITOA(CHANNEL.CHANNEL), $0D, $0A"
  }
}
*/

DATA_EVENT[dvSwitch]
{
  STRING:
  {
    SEND_STRING 0,      "'DVX REPLY: ', DATA.TEXT"
    SEND_STRING dvPush, "DATA.TEXT, $0D, $0A"
  }
}