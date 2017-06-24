#include <SoftwareSerial.h>

int pin_1 = 13; //定义引脚为13
int pin_2 = 12; //定义引脚为12

unsigned long duration;
unsigned long duration_2;
String last_mode = "off";
int last_temp;
boolean if_open = false;

unsigned char comdata[32][5] = {
  {},
  {0x02, 0x00, 0x21, 0x08, 0x2B},//设置遥控器
  {0x04, 0xFF, 0x08, 0x08, 0xFB}, //发送开机
  {0x04, 0x00, 0x08, 0x08, 0x04}, //关机
  {0x05, 0x00, 0x08, 0x08, 0x05}, //自动
  {0x05, 0x01, 0x08, 0x08, 0x04}, //制冷
  {0x05, 0x04, 0x08, 0x08, 0x01}, //制暖
  {},
  {},
  {},
  {},
  {},
  {},
  {},
  {},
  {},
  {0x06, 0x10, 0x08, 0x08, 0x16},
  {0x06, 0x11, 0x08, 0x08, 0x17},
  {0x06, 0x12, 0x08, 0x08, 0x14},
  {0x06, 0x13, 0x08, 0x08, 0x15},
  {0x06, 0x14, 0x08, 0x08, 0x12},
  {0x06, 0x15, 0x08, 0x08, 0x13},
  {0x06, 0x16, 0x08, 0x08, 0x10},
  {0x06, 0x17, 0x08, 0x08, 0x11},
  {0x06, 0x18, 0x08, 0x08, 0x1E},
  {0x06, 0x19, 0x08, 0x08, 0x1F},
  {0x06, 0x1A, 0x08, 0x08, 0x1C},
  {0x06, 0x1B, 0x08, 0x08, 0x1D},
  {0x06, 0x1C, 0x08, 0x08, 0x1A},
  {0x06, 0x1D, 0x08, 0x08, 0x1B},
  {0x06, 0x1E, 0x08, 0x08, 0x18},
  {0x06, 0x1F, 0x08, 0x08, 0x19}
};

SoftwareSerial infraredSerial(10, 11);

void setup()
{
  Serial.begin(9600); //串口波特率为9600
  infraredSerial.begin(9600);
  pinMode(pin_1, INPUT); //设置引脚为输入模式
  pinMode(pin_2, INPUT); //设置引脚为输入模式
}
void loop()
{
  delay(1000);
  duration = pulseIn(pin_1, HIGH);
  duration_2 = pulseIn(pin_2, HIGH);
  Serial.print("Last:");
  Serial.println(last_mode);
  if (duration < 200 and duration > 10 and last_mode != "off") {
    Serial.println("off");
    infraredSerial.flush();
    infraredSerial.write(comdata[1], 5);
    delay(200);
    infraredSerial.write(comdata[3], 5);
    if_open = false;
    last_mode = "off";
  } else if (duration > 300 and duration < 400 and last_mode != "hot") {
    Serial.println("hot");
    infraredSerial.flush();
    infraredSerial.write(comdata[1], 5);
    open_it();
    delay(800);
    infraredSerial.write(comdata[6], 5);
    last_mode = "hot";
  } else if (duration > 500 and duration < 600 and last_mode != "cold") {
    Serial.println("cold");
    infraredSerial.flush();
    infraredSerial.write(comdata[1], 5);
    open_it();
    delay(800);
    infraredSerial.write(comdata[5], 5);
    last_temp = 0;
    last_mode = "cold";
  } else if (duration > 700 and last_mode != "auto") {
    Serial.println("auto");
    infraredSerial.flush();
    infraredSerial.write(comdata[1], 5);
    open_it();
    delay(800);
    infraredSerial.write(comdata[4], 5);
    last_mode = "auto";
  }

  if (duration_2 < 315 and duration_2 > 10) {
    set_temp(16);
    Serial.println("16");
  } else if (duration_2 > 310 and duration_2 < 338) {
    set_temp(17);
    Serial.println("17");
  } else if (duration_2 > 338 and duration_2 < 358) {
    set_temp(18);
    Serial.println("18");
  } else if (duration_2 > 358 and duration_2 < 378) {
    set_temp(19);
    Serial.println("19");
  } else if (duration_2 > 378 and duration_2 < 398) {
    set_temp(20);
    Serial.println("20");
  } else if (duration_2 > 398 and duration_2 < 418) {
    set_temp(21);
    Serial.println("21");
  } else if (duration_2 > 418 and duration_2 < 438) {
    set_temp(22);
    Serial.println("22");
  } else if (duration_2 > 438 and duration_2 < 458) {
    set_temp(23);
    Serial.println("23");
  } else if (duration_2 > 458 and duration_2 < 478) {
    set_temp(24);
    Serial.println("24");
  } else if (duration_2 > 478 and duration_2 < 498) {
    set_temp(25);
    Serial.println("25");
  } else if (duration_2 > 498 and duration_2 < 518) {
    set_temp(26);
    Serial.println("26");
  } else if (duration_2 > 518 and duration_2 < 538) {
    set_temp(27);
    Serial.println("27");
  } else if (duration_2 > 538 and duration_2 < 558) {
    set_temp(28);
    Serial.println("28");
  } else if (duration_2 > 558 and duration_2 < 578) {
    set_temp(29);
    Serial.println("29");
  } else if (duration_2 > 578 and duration_2 < 598) {
    set_temp(30);
    Serial.println("30");
  } else if (duration_2 > 598) {
    set_temp(31);
    Serial.println("31");
  }

}

void open_it() {
  if (if_open == false) {
    delay(100);
    infraredSerial.write(comdata[2], 5);
    delay(100);
    Serial.println("Open it");
    if_open = true;
  }
}

void set_temp(int temp) {
  if (last_temp != temp) {
    delay(800);
    infraredSerial.write(comdata[temp], 5);
    delay(100);
    Serial.print("Write:");
    Serial.println(temp);
    last_temp = temp;
  }
}
