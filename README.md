# Spin Playground

(Spin)[http://spinroot.com/spin/whatispin.html] is a a popular open-source software verification tool.

```bash
./spin -f '![]p' > not_p.ltl
./spin -a -N not_p.ltl example.p
gcc -o pan pan.c
./pan
```
