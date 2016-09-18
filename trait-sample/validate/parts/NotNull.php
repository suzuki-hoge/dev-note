<?php

trait NotNull
{
    private function assertNotNull($value)
    {
        return !is_null($value);
    }
}