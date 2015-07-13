# Spin Playground

[Spin](http://spinroot.com/spin/whatispin.html) is a a popular open-source software verification tool.

```bash
./spin -f '![]p' > not_p.ltl
./spin -a -N not_p.ltl example.p
gcc -o pan pan.c
./pan
```

# 説明
SpinはLTLとを用いたマルチスレッドのシステムのモデルチェッカーである。

SpinではチェックしたいプログラムをPromelaという独自の言語で書く。
例えば、次のような感じになる：

```
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
  assert(x != N)
}
```

グローバル変数xとt1とt2を複数のスレッドが参照・書き換えるため、明らかに「危ない」例である。

Spinは、最後のassertが破られる可能性があるかどうかをチェックする。

例えば、N=1とした場合、Thread1/Thread2が実行されるまえにassert文がスケジュールされると破られる。

N=2の場合、asset文の前に一つのスレッドが最初から最後まで実行された場合、assertが破られる。

Spinでは、スレッドがスケジュールされる実行順を列挙するcomputation treeを構成し、これを検査する。

Spinでは幾つかの方法で検査できる。

## ランダム・サーチ
```
spin <model-file>
```
とすると、適当にcomputation searchをたどった場合にassertがどうなるかをチェックする。
C言語でassertを書いて何回も実行させるのと同じ。N=1として実行してみると、

```
% ./spin ex.1a
spin: ex.1a:17, Error: assertion violated
spin: text of failed assertion: assert((x!=1))
#processes: 3
x = 1
t1 = 1
t2 = 0
  5: proc  2 (Thread2:1) ex.1a:9 (state 4)
  5: proc  1 (Thread1:1) ex.1a:4 (state 2)
  5: proc  0 (:init::1) ex.1a:17 (state 4)
3 processes created
```
となり、破られることがわかる。
最後の3行は破られた時の各スレッドの状況であり、行数を見るとinitスレッドが他のスレッドがxを書き換える前に参照したことがわかる。
Soundnessはあるが、Completenessは無い。

## Guided-Simulation
次のステップでどれにスケジュールするかのスレッドを選びながら実行できる。
ランダムサーチをたどるのを人に任せているので、選び方によってはもちろん破られるはずのassertが破られないことがある。

```
% ./spin -i example.p
```

## Exhaustive Depth-first Search
computation treeを深さ優先で探索することで、assertが破られるかどうか調べる。
SpinではモデルをC言語に変換し、その上でサーチを行う。
先ほどの例でやってみると、

```
% ./pan
hint: this search is more efficient if pan.c is compiled -DSAFETY
pan:1: assertion violated (x!=1) (at depth 1349)
pan: wrote ex.1a.trail

(Spin Version 6.4.3 -- 16 December 2014)
Warning: Search not completed
+ Partial Order Reduction

Full statespace search for:
never claim         - (none specified)
assertion violations +
acceptance   cycles - (not selected)
invalid end states +

State-vector 36 byte, depth reached 1638, errors: 1
    10006 states, stored
    13563 states, matched
    23569 transitions (= stored+matched)
        0 atomic steps
hash conflicts:         4 (resolved)

Stats on memory usage (in Megabytes):
    0.611 equivalent memory usage for states (stored*(State-vector + overhead))
    0.584 actual memory usage for states (compression: 95.64%)
          state-vector as stored = 33 byte + 28 byte overhead
  128.000 memory used for hash table (-w24)
    0.534 memory used for DFS stack (-m10000)
  129.022 total actual memory usage



pan: elapsed time 0.01 seconds
```

となり、破られることがわかる。

## LTLによるモデル検査
上記ではassertを使っているが、LTLによる記述も行うことができる。
まず、LTLをPromelaモデルに変換する。この時に「みたしたい性質の否定」を入力しなければならない。

```
% ./spin -f '![]p'
never  {    /* ![]p */
T0_init:
do
:: atomic { (! ((p))) -> assert(!(! ((p)))) }
:: (1) -> goto T0_init
od;
accept_all:
skip
}
```

そして、モデルに使った述語の実装を追加しておく。
```
#define p       (x != 1)
```

```
% ./spin -a -N p.ltl ex.1a
```

として合成して生成されたCコードをコンパイルして実行すると、

```
% ./pan -a
warning: for p.o. reduction to be valid the never claim must be
stutter-invariant
(never claims generated from LTL formulae are stutter-invariant)
pan:1: assertion violated  !( !((x!=1))) (at depth 2)
pan: wrote ex.1a.trail
```

となり、やはり破られることがわかる。
