#!/usr/bin/perl

$head = undef;  # Голова списка

while (1) {
    print "\nВыберите операцию:\n";
    print "1. Добавить студента\n";
    print "2. Удалить студента\n";
    print "3. Вывести список студентов\n";
    print "4. Выйти\n";
    print "Ваш выбор: ";
    
    chomp($choice = <>);

    if ($choice == 1) {
        print "Введите ФИО: ";
        chomp($name = <>);

        print "Введите номер зачетной книжки: ";
        chomp($id = <>);

        print "Введите номер группы: ";
        chomp($group = <>);

        print "Введите специальность: ";
        chomp($specialty = <>);

        print "Введите год рождения: ";
        chomp($birth_year = <>);

        %student = (
            name       => $name,
            id         => $id,
            group      => $group,
            specialty  => $specialty,
            birth_year => $birth_year
        );

        insert(\$head, \%student);
    }
    elsif ($choice == 2) {
        print "Введите номер зачетной книжки студента, которого нужно удалить: ";
        chomp($id = <>);
        delete_student(\$head, $id);
    }
    elsif ($choice == 3) {
    	print "Список студентов:\n\n";
        list_print($head);
    }
    elsif ($choice == 4) {
        last;
    } else {
        print "Неверный выбор!\n";
    }
}

sub insert {
    ($item_ref, $student_ref) = @_;
    $item = $$item_ref;

    unless ($item) {
        $item = {
            INFO => $student_ref,
            NEXT => undef
        };
        $$item_ref = $item;
        return;
    }

    if ($item->{INFO}->{id} eq $student_ref->{id}) {
        warn "Студент с таким номером зачетной книжки уже существует!\n";
        return;
    }

    # Если текущий элемент имеет больший ключ, вставляем перед ним
    if ($item->{INFO}->{id} gt $student_ref->{id}) {
        $new_item = {
            INFO => $student_ref,
            NEXT => $item
        };
        $$item_ref = $new_item;
        return;
    }

    # Иначе продолжаем искать место для вставки
    insert(\$item->{NEXT}, $student_ref);
}

# Удаление студента из списка по номеру зачетной книжки
sub delete_student {
    ($item_ref, $id) = @_;
    $item = $$item_ref;

    unless ($item) {
        print "Студент с таким номером зачетной книжки не найден!\n";
        return;
    }

    if ($item->{INFO}->{id} eq $id) {
        $$item_ref = $item->{NEXT};  # Перемещаем указатель на следующий элемент
        print "Студент с номером зачетной книжки $id удален.\n";
        return;
    }

    delete_student(\$item->{NEXT}, $id);
}

# Печать списка студентов
sub list_print {
    ($item) = @_;
    unless ($item) {
        return;
    }

    $info = $item->{INFO};
    print "ФИО: $info->{name},\nНомер зачетной книжки: $info->{id},\nГруппа: $info->{group},\nСпециальность: $info->{specialty},\nГод рождения: $info->{birth_year}\n";
    list_print($item->{NEXT});
}




