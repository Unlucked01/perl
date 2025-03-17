package Matrix;

use strict;
use warnings;

# Конструктор
sub new {
    my ($class, $rows, $cols, $data) = @_;
    
    my $self = {
        rows => $rows,
        cols => $cols,
        data => $data || [],
    };
    
    # Инициализация пустой матрицы, если данные не предоставлены
    unless ($data) {
        for my $i (0..$rows-1) {
            for my $j (0..$cols-1) {
                $self->{data}[$i][$j] = 0;
            }
        }
    }
    
    bless $self, $class;
    return $self;
}

# Заполнение матрицы случайными числами
sub fill_random {
    my ($self, $min, $max) = @_;
    $min //= -10;
    $max //= 10;
    
    for my $i (0..$self->{rows}-1) {
        for my $j (0..$self->{cols}-1) {
            $self->{data}[$i][$j] = $min + int(rand($max - $min + 1));
        }
    }
    
    return $self;
}

# Получение элемента матрицы
sub get {
    my ($self, $row, $col) = @_;
    return $self->{data}[$row][$col];
}

# Установка элемента матрицы
sub set {
    my ($self, $row, $col, $value) = @_;
    $self->{data}[$row][$col] = $value;
    return $self;
}

# Вывод матрицы в строковом формате
sub to_string {
    my ($self) = @_;
    my $result = "";
    
    for my $i (0..$self->{rows}-1) {
        for my $j (0..$self->{cols}-1) {
            $result .= sprintf("%8.2f", $self->{data}[$i][$j]);
        }
        $result .= "\n";
    }
    
    return $result;
}

# Вывод матрицы в HTML-формате
sub to_html {
    my ($self) = @_;
    my $result = "<table class='matrix'>";
    
    for my $i (0..$self->{rows}-1) {
        $result .= "<tr>";
        for my $j (0..$self->{cols}-1) {
            $result .= "<td>" . sprintf("%.2f", $self->{data}[$i][$j]) . "</td>";
        }
        $result .= "</tr>";
    }
    
    $result .= "</table>";
    return $result;
}

# Транспонирование матрицы
sub transpose {
    my ($self) = @_;
    my $result = Matrix->new($self->{cols}, $self->{rows});
    
    for my $i (0..$self->{rows}-1) {
        for my $j (0..$self->{cols}-1) {
            $result->{data}[$j][$i] = $self->{data}[$i][$j];
        }
    }
    
    return $result;
}

# Поиск максимального элемента
sub max {
    my ($self) = @_;
    my $max = $self->{data}[0][0];
    
    for my $i (0..$self->{rows}-1) {
        for my $j (0..$self->{cols}-1) {
            $max = $self->{data}[$i][$j] if $self->{data}[$i][$j] > $max;
        }
    }
    
    return $max;
}

# Поиск минимального элемента
sub min {
    my ($self) = @_;
    my $min = $self->{data}[0][0];
    
    for my $i (0..$self->{rows}-1) {
        for my $j (0..$self->{cols}-1) {
            $min = $self->{data}[$i][$j] if $self->{data}[$i][$j] < $min;
        }
    }
    
    return $min;
}

# Сложение матриц
sub add {
    my ($self, $other) = @_;
    
    # Проверка размерностей
    if ($self->{rows} != $other->{rows} || $self->{cols} != $other->{cols}) {
        die "Невозможно сложить матрицы разных размеров";
    }
    
    my $result = Matrix->new($self->{rows}, $self->{cols});
    
    for my $i (0..$self->{rows}-1) {
        for my $j (0..$self->{cols}-1) {
            $result->{data}[$i][$j] = $self->{data}[$i][$j] + $other->{data}[$i][$j];
        }
    }
    
    return $result;
}

# Умножение матриц
sub multiply {
    my ($self, $other) = @_;
    
    # Проверка размерностей
    if ($self->{cols} != $other->{rows}) {
        die "Невозможно умножить матрицы: количество столбцов первой матрицы должно быть равно количеству строк второй матрицы";
    }
    
    my $result = Matrix->new($self->{rows}, $other->{cols});
    
    for my $i (0..$self->{rows}-1) {
        for my $j (0..$other->{cols}-1) {
            my $sum = 0;
            for my $k (0..$self->{cols}-1) {
                $sum += $self->{data}[$i][$k] * $other->{data}[$k][$j];
            }
            $result->{data}[$i][$j] = $sum;
        }
    }
    
    return $result;
}

# Вычисление определителя (для квадратных матриц)
sub determinant {
    my ($self) = @_;
    
    # Проверка, что матрица квадратная
    if ($self->{rows} != $self->{cols}) {
        die "Определитель можно вычислить только для квадратной матрицы";
    }
    
    # Для матрицы 1x1
    if ($self->{rows} == 1) {
        return $self->{data}[0][0];
    }
    
    # Для матрицы 2x2
    if ($self->{rows} == 2) {
        return $self->{data}[0][0] * $self->{data}[1][1] - $self->{data}[0][1] * $self->{data}[1][0];
    }
    
    # Для матриц большего размера используем разложение по первой строке
    my $det = 0;
    for my $j (0..$self->{cols}-1) {
        my $minor = $self->_minor(0, $j);
        my $cofactor = $self->{data}[0][$j] * (($j % 2 == 0) ? 1 : -1);
        $det += $cofactor * $minor->determinant();
    }
    
    return $det;
}

# Вычисление минора матрицы (вспомогательная функция)
sub _minor {
    my ($self, $row, $col) = @_;
    
    my $minor = Matrix->new($self->{rows} - 1, $self->{cols} - 1);
    my $r = 0;
    
    for my $i (0..$self->{rows}-1) {
        next if $i == $row;
        my $c = 0;
        for my $j (0..$self->{cols}-1) {
            next if $j == $col;
            $minor->{data}[$r][$c] = $self->{data}[$i][$j];
            $c++;
        }
        $r++;
    }
    
    return $minor;
}

# Вычисление обратной матрицы
sub inverse {
    my ($self) = @_;
    
    # Проверка, что матрица квадратная
    if ($self->{rows} != $self->{cols}) {
        die "Обратную матрицу можно вычислить только для квадратной матрицы";
    }
    
    my $det = $self->determinant();
    
    # Проверка, что определитель не равен нулю
    if (abs($det) < 1e-10) {
        die "Невозможно вычислить обратную матрицу: определитель равен нулю";
    }
    
    # Для матрицы 1x1
    if ($self->{rows} == 1) {
        my $result = Matrix->new(1, 1);
        $result->{data}[0][0] = 1 / $self->{data}[0][0];
        return $result;
    }
    
    # Для матриц большего размера используем матрицу алгебраических дополнений
    my $cofactors = Matrix->new($self->{rows}, $self->{cols});
    
    for my $i (0..$self->{rows}-1) {
        for my $j (0..$self->{cols}-1) {
            my $minor = $self->_minor($i, $j);
            my $sign = (($i + $j) % 2 == 0) ? 1 : -1;
            $cofactors->{data}[$i][$j] = $sign * $minor->determinant();
        }
    }
    
    # Транспонируем матрицу алгебраических дополнений
    my $adjugate = $cofactors->transpose();
    
    # Делим на определитель
    my $result = Matrix->new($self->{rows}, $self->{cols});
    for my $i (0..$self->{rows}-1) {
        for my $j (0..$self->{cols}-1) {
            $result->{data}[$i][$j] = $adjugate->{data}[$i][$j] / $det;
        }
    }
    
    return $result;
}

1; 