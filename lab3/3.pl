#!/usr/bin/perl

print "Введите количество дисков: ";
chomp($n = <>);

@A = reverse(1..$n);  # Стержень A (исходный)
@B = ();              # Стержень B (вспомогательный)
@C = ();              # Стержень C (целевой)

print_state();
hanoi($n, 'A', 'C', 'B');

sub hanoi {
    my ($n, $from, $to, $aux) = @_;
    
    if ($n == 1) {
        move_disk($from, $to);
        print_state();
        return;
    }

    # Перемещаем n-1 дисков на вспомогательный стержень
    hanoi($n - 1, $from, $aux, $to);
    
    # Перемещаем оставшийся самый большой диск на целевой стержень
    move_disk($from, $to);
    print_state();

    # Перемещаем n-1 дисков со вспомогательного стержня на целевой
    hanoi($n - 1, $aux, $to, $from);
}

# Функция перемещения диска между стержнями
sub move_disk {
    my ($from, $to) = @_;

    my $disk = eval "\@$from";  # Получаем последний диск с стержня $from
    eval "push \@$to, pop \@$from"; # Перемещаем диск со стержня $from на стержень $to
    print "Перенос диска диаметра $disk со стержня $from на стержень $to.\n";
}

# Функция вывода текущего состояния стержней
sub print_state {
    print "\nТекущее состояние стержней:\n";
    print "Стержень A: @A\n";
    print "Стержень B: @B\n";
    print "Стержень C: @C\n\n";
}