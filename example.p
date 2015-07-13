#define p       (x != 1)

byte x,t1,t2;
proctype Thread1(){
  do :: t1 = x;
    t2 = x;
    x = t1 + t2
  od
}
proctype Thread2(){
  do :: t1 = x;
    t2 = x;
    x = t1 + t2
  od
}
init{
  x = 1;
  run Thread1(); run Thread2();
}
