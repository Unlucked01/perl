#! /bin/usr/perl

print "\nКак Ваше имя? ";
$name= <STDIN>;
print "\nСколько Вам лет? ";
$age = <STDIN>;
print "\n";
$~=SALUT_FORMAT;
$^=SALUT_FORMAT_TOP;
write;
format SALUT_FORMAT=
Поздравляем Вас, ^>>>>>>>>>>>>>>>!
$name
Сегодня, в возpасте @###.## лет Вы написали
$age
свою пеpвую Perl-пpогpамму !
.
format SALUT_FORMAT_TOP=
*******Пеpвый сценарий на Perl*******
.