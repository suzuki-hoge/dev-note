<?php

require_once 'UserIdValidator.php';
require_once 'UserNameValidator.php';

$userIdValidator = new UserIdValidator();
var_dump($userIdValidator->isValid(null));
var_dump($userIdValidator->isValid('user-1@3'));
var_dump($userIdValidator->isValid('user-123'));


$userNameValidator = new UserNameValidator();
var_dump($userNameValidator->isValid('doe'));
var_dump($userNameValidator->isValid('j@ck'));
var_dump($userNameValidator->isValid('jack'));

