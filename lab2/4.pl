#!/usr/bin/perl

%hash = ("enter" => "");

while (1) {
    print "\n1. Добавить строку\n";
    print "2. Удалить строку\n";
    print "3. Просмотреть список\n";
    print "4. Выход\n";
    print "Выберите действие: ";
    chomp($choice = <>);
    
    if ($choice == 1) {
        print "Введите строку для добавления: ";
	    chomp($new_string = <>);
	    $prev = "enter";
	    $current = $hash{$prev};
	    
	    while ($current && $current lt $new_string) {
	        $prev = $current;
	        $current = $hash{$current};
	    }
	    
	    $hash{$prev} = $new_string;
	    $hash{$new_string} = $current;
	    print "Строка '$new_string' добавлена.\n";

    } elsif ($choice == 2) {
        print "Введите строку для удаления: ";
	    chomp(my $del_string = <>);
	    $prev = "enter";
	    $current = $hash{$prev};
	    
	    while ($current && $current ne $del_string) {
	        $prev = $current;
	        $current = $hash{$current};
	    }
	    
	    if ($current) {
	        $hash{$prev} = $hash{$current};
	        delete $hash{$current};
	        print "Строка '$del_string' удалена.\n";
	    } else {
	        print "Строка '$del_string' не найдена.\n";
	    }

    } elsif ($choice == 3) {
        $current = $hash{"enter"};
	    if (!$current) {
	        print "Список пуст.\n";
	        return;
	    }
	    
	    print "Список строк:\n";
	    while ($current) {
	        print "$current\n";
	        $current = $hash{$current};
	    }

    } elsif ($choice == 4) {
        print "Выход.\n";
        last;
    } else {
        print "Неверный выбор. Попробуйте снова.\n";
    }
}