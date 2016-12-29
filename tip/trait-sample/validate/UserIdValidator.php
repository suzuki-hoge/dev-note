<?php

require_once 'parts/NotNull.php';
require_once 'parts/Regex.php';
require_once 'parts/Character.php';

class UserIdValidator
{
    use NotNull;
    use Regex;
    use Character;

    public function isValid($value)
    {
        return
            $this->assertNotNull($value) and
            $this->assertRegex($value, '/user-.../') and
            $this->assertNoAtMark($value);
    }
}