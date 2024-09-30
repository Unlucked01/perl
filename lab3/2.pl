#!/usr/bin/perl

$root = undef;  # Корень дерева

while (1) {
    print "\nВыберите операцию:\n";
    print "1. Добавить элемент\n";
    print "2. Удалить элемент\n";
    print "3. Вывести дерево\n";
    print "4. Выйти\n";
    print "Ваш выбор: ";
    
    chomp($choice = <>);

    if ($choice == 1) {
        my @values_to_add = ();
        while(1) {
            print "Введите число для добавления: ";
            chomp($value = <>);
            last if $value eq '';
            push(@values_to_add, $value);
        }
        foreach $v (@values_to_add) {
            insert(\$root, $v);
        }
    }
    elsif ($choice == 2) {
        print "Введите число для удаления: ";
        chomp($value = <>);

        if (delete_node(\$root, $value)) {
            print "Значение $value удалено из дерева.\n";
        } else {
            print "Значение $value не найдено в дереве.\n";
        }

    }
    elsif ($choice == 3) {
        print "Дерево элементов:\n";
        print_tree($root, 0);
    }
    elsif ($choice == 4) {
        last;
    } else {
        print "Неверный выбор!\n";
    }
}

sub insert {
    my ($node_ref, $value) = @_;
    my $node = $$node_ref;

    unless ($node) {
        $node = {
            INFO => $value,
            LEFT  => undef,
            RIGHT => undef
        };
        $$node_ref = $node;
        return;
    }

    if ($value < $node->{INFO}) {
        insert(\$node->{LEFT}, $value);
    } elsif ($value > $node->{INFO}) {
        insert(\$node->{RIGHT}, $value);
    } else {
        warn "Значение $value уже существует в дереве!\n";
    }
}

sub delete_node {
    my ($node_ref, $value) = @_;
    my $node = $$node_ref;

    return 0 unless $node;

    if ($value < $node->{INFO}) {
        return delete_node(\$node->{LEFT}, $value);
    } elsif ($value > $node->{INFO}) {
        return delete_node(\$node->{RIGHT}, $value);
    } else {
        if (!$node->{LEFT} && !$node->{RIGHT}) {
            # Случай 1: Узел — лист
            $$node_ref = undef;
        } elsif (!$node->{LEFT}) {
            # Случай 2: Узел имеет только правого потомка
            $$node_ref = $node->{RIGHT};
        } elsif (!$node->{RIGHT}) {
            # Случай 2: Узел имеет только левого потомка
            $$node_ref = $node->{LEFT};
        } else {
            # Случай 3: Узел имеет двух потомков
            my $successor = find_min($node->{RIGHT});
            $node->{INFO} = $successor->{INFO};
            delete_node(\$node->{RIGHT}, $successor->{INFO});
        }
        return 1;
    }
}

# Поиск минимума в поддереве
sub find_min {
    my ($node) = @_;
    while ($node->{LEFT}) {
        $node = $node->{LEFT};
    }
    return $node;
}

# Функция печати дерева с отступами
sub print_tree {
    my ($node, $depth) = @_;
    return unless $node;

    print_tree($node->{RIGHT}, $depth + 1);

    print " " x (4 * $depth);
    print "$node->{INFO}\n";

    print_tree($node->{LEFT}, $depth + 1);
}