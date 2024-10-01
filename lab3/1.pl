#!/usr/bin/perl

$head = undef;

while (1) {
    print "\nВыберите операцию:\n";
    print "1. Добавить студента\n";
    print "2. Удалить студента\n";
    print "3. Вывести список студентов\n";
    print "4. Выйти\n";
    print "Ваш выбор: ";
    
    chomp($choice = <>);

    if ($choice == 1) {
        print "Введите номер зачетной книжки: ";
        chomp($id = <>);
        print "Введите ФИО: ";
        chomp ($fio = <>);
        print "Введите название группы: ";
        chomp ($group = <>);
        print "Введите специальность: ";
        chomp ($spec = <>);
        print "Введите год рождения: ";
        chomp ($birth = <>);

        my %student = (
            id         => $id,
            fio       => $fio,
            group      => $group,
            speciality  => $spec,
            birth_year => $birth
        );

        $head = append($head, \%student);
        
        print "Добавление выполнено.\n";

    } elsif ($choice == 2) {
        print "Введите значение для удаления: ";
        chomp ($value = <>);

        $head = my_delete($head, $value);
        
    } elsif ($choice == 3) {
        print_list($head);
    } elsif ($choice == 4) {
        print "Выход\n";
        last;
    } else {
        print "Такой опции не существует\n";
    }
}

sub append {
    my ($head, $new_node) = @_;

    if (!$head || $new_node->{id} <= $head->{id}) {
        $new_node->{next} = $head;
        return $new_node;
    }

    $head->{next} = append($head->{next}, $new_node);
    return $head;
}

sub my_delete {
    my ($head, $value) = @_;
    if (!$head) {
        return $head;
    }
    if ($head->{id} == $value) {
        return $head->{next};
    }
    $head->{next} = my_delete($head->{next}, $value);
    return $head;
}

sub print_list {
    my ($head) = @_;
    if (!$head) {
        return;
    }

    print "Номер зачетной книжки: $head->{id}\nФИО: $head->{fio}\nГруппа: $head->{group}\nСпециальность: $head->{speciality}\nГод рождения: $head->{birth_year}\n\n";
    print_list($head->{next});
}




