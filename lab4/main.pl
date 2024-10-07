#!/usr/bin/perl

use lib '.';
use Student;

my $head = undef;

while (1) {
    print "\nВыберите операцию:\n";
    print "1. Добавить студента\n";
    print "2. Удалить студента\n";
    print "3. Вывести список студентов\n";
    print "4. Сравнить студентов\n";
    print "5. Выйти\n";
    print "Ваш выбор: ";
    
    chomp(my $choice = <>);

    if ($choice == 1) {
        print "Введите номер зачетной книжки: ";
        chomp(my $id = <>);
        print "Введите ФИО: ";
        chomp(my $fio = <>);
        print "Введите название группы: ";
        chomp(my $group = <>);
        print "Введите специальность: ";
        chomp(my $spec = <>);
        print "Введите год рождения: ";
        chomp(my $birth = <>);
        print "Введите оценки через пробел: ";
        chomp(my $grades_input = <>);
        my @grades = split(' ', $grades_input);  # Разделяем оценки
        my $student = Student->new($id, $fio, $group, $spec, $birth, @grades);
        
        $head = $head ? $head->append($student) : $student;
        print Dumper(\$head);
        print "Добавление выполнено.\n";

    } elsif ($choice == 2) {
        print "Введите номер зачетной книжки для удаления: ";
        chomp(my $value = <>);
        $head = $head ? $head->my_delete($value) : undef;
    } elsif ($choice == 3) {
    	$head ? $head->print_list() : print "Список студентов пуст.\n";
    } elsif ($choice == 4) {
        print "Введите номер зачетной книжки первого студента: ";
        chomp(my $id1 = <>);
        print "Введите номер зачетной книжки второго студента: ";
        chomp(my $id2 = <>);
        my $student1 = $head->find_student($id1) if $head;
        my $student2 = $head->find_student($id2) if $head;
        if ($student1 && $student2) {
            print Student::compare($student1, $student2);
        } else {
            print "Один из студентов не найден.\n";
        }
    } elsif ($choice == 5) {
        print "Выход\n";
        last;
    } else {
        print "Такой опции не существует\n";
    }
}