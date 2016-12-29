<?php

trait Regex
{
    private function assertRegex($value, $pattern)
    {
        return preg_match($pattern, $value) === 1;
    }
}