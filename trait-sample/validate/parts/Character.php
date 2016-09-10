<?php

trait Character
{
    private function assertNoAtMark($value)
    {
        return strpos($value, '@') === false;
    }
}