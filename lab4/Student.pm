package Student;

sub new {
    my ($class, $id, $fio, $group, $speciality, $birth_year, @grades) = @_;
    my $self = {
        id         => $id,
        fio        => $fio,
        group      => $group,
        speciality => $speciality,
        birth_year => $birth_year,
        grades     => \@grades,  # Массив оценок
        next       => undef
    };
    bless $self, $class;
    return $self;
}

sub DESTROY {
    my $self = shift;
    print "Студент с номером зачетной книжки $self->{id} удален.\n";
}

sub get_average {
    my ($self) = @_;
    my $grades = $self->{grades};
    return 0 unless @$grades;  # Если нет оценок, средний балл = 0
    my $sum = 0;
    $sum += $_ for @$grades;
    return $sum / @$grades;
}

sub compare {
    my ($student1, $student2) = @_;
    my $avg1 = $student1->get_average;
    my $avg2 = $student2->get_average;

    if ($avg1 > $avg2) {
        return "$student1->{fio} (с баллом $avg1) учится лучше, чем $student2->{fio} (с баллом $avg2).\n";
    } elsif ($avg1 < $avg2) {
        return "$student2->{fio} (с баллом $avg2) учится лучше, чем $student1->{fio} (с баллом $avg1).\n";
    } else {
        return "$student1->{fio} (с баллом $avg1) и $student2->{fio} (с баллом $avg2) учатся одинаково хорошо.\n";
    }
}

sub append {
    my ($self, $new_node) = @_;
    
    if (!$self || $new_node->{id} <= $self->{id}) {
        $new_node->{next} = $self;
        return $new_node;
    }

    $self->{next} = append($self->{next}, $new_node); 
    return $self;
}

sub my_delete {
    my ($self, $value) = @_;
    if (!$self) {
        return undef;
    }
    if ($self->{id} == $value) {
    	my $next = $self->{next};
        undef $self;  # Здесь вызовется деструктор для текущего объекта
        return $next;
    }
    $self->{next} = $self->{next}->my_delete($value) if $self->{next};
    return $self;
}

sub find_student {
    my ($self, $id) = @_;
    my $current = $self;
    while ($current) {
        return $current if $current->{id} == $id;
        $current = $current->{next};
    }
    return undef;
}

sub print_list {
    my ($self) = @_;
    my $current = $self;
    while ($current) {
        print "Номер зачетной книжки: $current->{id} ФИО: $current->{fio} Группа: $current->{group} Специальность: $current->{speciality} Год рождения: $current->{birth_year} Оценки: " . join(", ", @{$current->{grades}}) . "\n";
        $current = $current->{next};
    }
}

1;  # Конец модуля