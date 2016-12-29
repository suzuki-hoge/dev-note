<?php

trait Length
{
    private function assertMin($value, $length)
    {
        return $length <= strlen($value);
    }

    private function assertMax($value, $length)
    {
        return strlen($value) <= $length;
    }
}