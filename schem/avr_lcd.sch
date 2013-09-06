v 20110115 2
C 40000 40000 0 0 0 title-B.sym
C 44500 45700 1 0 0 lcd.sym
C 52400 43700 1 90 0 avr_328p.sym
N 46700 45800 46700 44500 4
N 46700 44500 48800 44500 4
N 48800 44500 48800 50500 4
N 48800 50500 50600 50500 4
N 50600 50500 50600 49400 4
N 46900 45800 46900 44600 4
N 46900 44600 48700 44600 4
N 48700 44600 48700 50400 4
N 48700 50400 50400 50400 4
N 50400 50400 50400 49400 4
N 47100 45800 47100 44700 4
N 47100 44700 48600 44700 4
N 48600 44700 48600 50300 4
N 48600 50300 50200 50300 4
N 50200 50300 50200 49400 4
N 47300 45800 47300 44800 4
N 47300 44800 48500 44800 4
N 48500 44800 48500 50200 4
N 48500 50200 50000 50200 4
N 50000 50200 50000 49400 4
C 47600 45000 1 0 0 gnd-1.sym
N 47700 45800 47700 45300 4
C 47900 45600 1 0 0 vdd-1.sym
N 47500 45800 47500 44900 4
N 47500 44900 48100 44900 4
N 48100 44900 48100 45600 4
C 44600 45000 1 0 0 gnd-1.sym
N 44700 45800 44700 45300 4
C 43400 46500 1 0 0 vdd-1.sym
N 44900 45800 44900 44900 4
N 44900 44900 43600 44900 4
N 43600 44900 43600 46500 4
C 42900 45300 1 270 0 pot-1.sym
{
T 43800 44500 5 10 0 0 270 0 1
device=VARIABLE_RESISTOR
T 43500 44700 5 10 1 1 270 0 1
refdes=R1
T 44400 44500 5 10 0 0 270 0 1
footprint=none
T 43300 44700 5 10 1 1 270 0 1
value=10K-20K
}
N 45100 45800 45100 44800 4
N 45100 44800 43500 44800 4
C 42800 45400 1 0 0 vdd-1.sym
C 42900 44000 1 0 0 gnd-1.sym
N 43000 45400 43000 45300 4
N 43000 44400 43000 44300 4
N 45300 45800 45300 41700 4
N 45300 41700 52200 41700 4
N 52200 41700 52200 43800 4
N 45500 45800 45500 44300 4
N 45500 44300 49000 44300 4
N 49000 44300 49000 50700 4
N 49000 50700 52200 50700 4
N 52200 50700 52200 49400 4
N 45700 45800 45700 44400 4
N 45700 44400 48900 44400 4
N 48900 44400 48900 50600 4
N 48900 50600 52000 50600 4
N 52000 49400 52000 50600 4
C 50900 43400 1 0 0 gnd-1.sym
N 51000 43800 51000 43700 4
C 43700 46300 1 270 0 capacitor-1.sym
{
T 44400 46100 5 10 0 0 270 0 1
device=CAPACITOR
T 44200 45700 5 10 1 1 270 0 1
refdes=C1
T 44600 46100 5 10 0 0 270 0 1
symversion=0.1
T 44000 45700 5 10 1 1 270 0 1
value=100n
}
C 43800 45000 1 0 0 gnd-1.sym
N 43900 46300 43900 46400 4
N 43900 46400 43600 46400 4
N 43900 45400 43900 45300 4
C 50300 43300 1 0 0 vdd-1.sym
C 50600 43100 1 270 0 capacitor-1.sym
{
T 51300 42900 5 10 0 0 270 0 1
device=CAPACITOR
T 51100 42500 5 10 1 1 270 0 1
refdes=C2
T 51500 42900 5 10 0 0 270 0 1
symversion=0.1
T 50900 42500 5 10 1 1 270 0 1
value=100n
}
C 50700 41800 1 0 0 gnd-1.sym
N 50500 43300 50500 43200 4
N 50500 43200 50800 43200 4
N 50800 43100 50800 43800 4
N 50800 42200 50800 42100 4
C 51200 49800 1 0 0 gnd-1.sym
N 50800 49400 50800 50300 4
N 50800 50300 51300 50300 4
N 51300 50300 51300 50100 4
N 51000 49400 51000 50300 4
C 52600 49700 1 0 0 vdd-1.sym
C 53000 48200 1 0 0 gnd-1.sym
N 52800 49700 52800 49600 4
N 51200 49600 53100 49600 4
N 53100 48600 53100 48500 4
C 52900 49500 1 270 0 capacitor-1.sym
{
T 53600 49300 5 10 0 0 270 0 1
device=CAPACITOR
T 53400 48900 5 10 1 1 270 0 1
refdes=C3
T 53800 49300 5 10 0 0 270 0 1
symversion=0.1
T 53200 48900 5 10 1 1 270 0 1
value=100n
}
N 53100 49600 53100 49500 4
N 51200 49400 51200 49600 4
T 50100 40800 9 16 1 0 0 0 1
AVR-to-LCD Connection
T 50000 40400 9 10 1 0 0 0 1
avr_lcd/avr_lcd.sch
T 53800 40400 9 10 1 0 0 0 1
1.0
T 53800 40100 9 10 1 0 0 0 1
Allen Baker
T 50000 40100 9 10 1 0 0 0 1
1
T 51500 40100 9 10 1 0 0 0 1
1