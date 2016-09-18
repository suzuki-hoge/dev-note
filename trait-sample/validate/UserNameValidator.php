<?php

require_once 'parts/NotNull.php';
require_once 'parts/Length.php';
require_once 'parts/Character.php';

class UserNameValidator
{
    use NotNull;
    use Length;
    use Character;

    public function isValid($value)
    {
        return
            $this->assertNotNull($value) and
            $this->assertMin($value, 4) and
            $this->assertMax($value, 8) and
            $this->assertNoAtMark($value);
    }
}