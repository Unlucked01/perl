#! /usr/bin/perl

$= =3;

print "\nВведите текущий день: ";
$day = <STDIN>;
print "Введите текущий месяц: ";
$month = <STDIN>;
print "Введите текущий год: ";
$year = <STDIN>;

$lab_topic = "Основы Perl";

$member1 = "Бобков";
$member2 = "Копылов";
$member3 = "Жигалов";

$~ = LAB_FORMAT;
$^ = LAB_FORMAT_TOP;

write;

format LAB_FORMAT =
		   Тема работы: 
^||||||||||||||||||||||||||||||||||||||||||||||||||||||
$lab_topic

Выполнили: 
^<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
$member1
^||||||||||||||||||||||||||||||||||||||||||||||||||||||
$member2
^>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
$member3
Текущая дата: @#.@#.@#
$day,$month,$year
.

# Верхний колонтитул
format LAB_FORMAT_TOP =
************* Лабораторная работа №1.2 ************
---------------------------------------------------
.