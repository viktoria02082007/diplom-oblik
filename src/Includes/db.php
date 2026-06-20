<?php

        // Параметри беруться зі змінних оточення (Railway MySQL),
        // а якщо їх немає — використовуються локальні значення (XAMPP / php -S).
        $host = getenv('MYSQLHOST')     ?: 'localhost';
        $user = getenv('MYSQLUSER')     ?: 'root';
        $pass = getenv('MYSQLPASSWORD') ?: '';
        $db   = getenv('MYSQLDATABASE') ?: 'impulse101';
        $port = getenv('MYSQLPORT')     ?: 3306;

        $con = mysqli_connect($host, $user, $pass, $db, (int)$port);

        if (mysqli_connect_errno()) {
                echo "Failed to connect to MySql " . mysqli_connect_error();
        }
