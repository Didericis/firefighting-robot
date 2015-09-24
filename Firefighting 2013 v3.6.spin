'Eric Bauerfeld
'2012-2013
'v1.0

CON

  'Robot diagram of sensors:
  '
  '        _____pMF_____
  '       /             \
  '     pRF             pLF
  '     /                 \
  '    |                   |
  '    |                   |
  '    |                   |
  '    |                   |
  '     \                 /
  '     pBR             pBL
  '       _______________
  '

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  '--Pin Declarations--
  Lin1 = 13     'Input 1 for left motor (Determines turning direction)
  Lin2 = 12     'Input 2 for left motor (Determines motor speed)
  Rin1 = 14     'Input 1 for right motor (Determines turning direction)
  Rin2 = 15     'Input 2 for right motor (Determines motor speed)
  pLF = 0       'Left Front Ping Sensor
  pMF = 1       'Mid Front Ping Sensor
  pRF = 2       'Right Front Ping Sensor
  pRB = 3       'Back Right Ping Sensor
  pLB = 4       'Back Left Ping Sensor

  pGt = 5       'LED when pRF_rec > pRF_read
  pEq = 6       'LED when pRF_rec == pRF_read
  pLs = 7       'LED when pRF_rec < pRF_read

  Front_Buffer = 200            'Distance (in mm) from wall after which robot will stop
  Min_Duty = 40                 'Minimum duty cycle fed to PWM object (determines min motor speed, must be between 0 and 100)
  Max_Duty = 70                 'Maximum duty cycle fed to PWM object (determines max motor speed, must be between 0 and 100)
  Forward_Duty = 55             'Duty cycle for both PWM objects when going straight (determines robot speed when going straight)
  Correction_Delay = 10         'Determines how fast robot corrects itself (bigger value = slower correction)

VAR
  long TestPingStack[256]
  long WallFollowStack[512]
  long ShitStack[256]
  long pLF_read
  long pMF_read
  long pRF_read
  long pRB_read
  long pLB_read
  byte skip

OBJ
  PWM:     "PWM_32_v4.spin"
  ping:    "Ping.spin"
  pst:     "FullDuplexSerial"
  TestPing:"TestPing.spin"

PUB main
  cognew(PINGUPDATE, @TestPingStack)
  cognew(WALLFOLLOW, @WallFollowStack)

PUB PINGUPDATE
  repeat
    pLF_read := ping.Millimeters(pLF)
    pMF_read := ping.Millimeters(pMF)
    pRF_read := ping.Millimeters(pRF)

PUB WALLFOLLOW | pMF_rec, pRF_rec, Forward_Buffer, LM_input, RM_input
  dira[Lin1] := 1
  dira[Lin2] := 1
  dira[Rin1] := 1
  dira[Rin2] := 1
  dira[pGt] := 1
  dira[pEq] := 1
  dira[pLs] := 1

  pst.start(31,30,0,115200)
  pst.str(String("START"))
  pst.tx(13)

  'Wait MF sensor is less than 50mm, then use RF sensor reading for right wall following
  repeat while (pMF_read > 50)
    STOP
  pRF_rec := pRF_read
  repeat 5000
    STOP

  skip := 0
  PWM.Start
  repeat

    'Checks distance readings for debugging purposes
    if pRF_read > pRF_rec
      outa[pGt] := 1
    if pRF_read == pRF_rec
      outa[pEq] := 1
    if pRF_read < pRF_rec
      outa[pLs] := 1

    LM_input := (Forward_Duty - (pRF_read - pRF_rec)/Correction_Delay)
    RM_input := (Forward_Duty - (pRF_read - pRF_rec)/Correction_Delay)
    if (pMF_read =< Front_Buffer)
      if skip == 0
        PWM.Stop
        skip := 1
        pst.str(string("Change skip to 1"))
        pst.tx(13)
        pst.dec(skip)
      STOP
    elseif (pMF_read > Front_Buffer)
      if skip == 1
        pst.str(string("Change skip to 0"))
        PWM.Start
        skip := 0
        pst.tx(13)
      elseif (RM_input > Min_Duty) & (LM_input > Min_Duty) & (RM_input < Max_Duty) & (LM_input < Max_Duty)
        outa[Rin1] := 0
        outa[Lin1] := 0
        PWM.PWM(Lin2, LM_input, 20)
        PWM.PWM(Rin2, RM_input, 20)
      elseif (RM_input =< Min_Duty) | (LM_input => Max_Duty)
        outa[Rin1] := 0
        outa[Lin1] := 0
        PWM.PWM(Rin2, Min_Duty, 20)
        PWM.PWM(Lin2, Max_Duty, 20)
      elseif (RM_input => Max_Duty) | (LM_input =< Min_Duty)
        outa[Rin1] := 0
        outa[Lin1] := 0
        PWM.PWM(Rin2, Max_Duty, 20)
        PWM.PWM(Lin2, Min_Duty, 20)

PRI FWARD
    outa[Lin1] := 0
    outa[Rin1] := 0
    PWM.PWM(Lin2, 35, 20)
    PWM.PWM(Rin2, 35, 20)

PRI STOP
    outa[Lin1] := 1
    outa[Rin1] := 1
    outa[Lin2] := 0
    outa[Rin2] := 0

