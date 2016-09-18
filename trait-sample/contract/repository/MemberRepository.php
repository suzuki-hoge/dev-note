<?php

namespace repository;


trait MemberRepository
{
    function saveMember($member)
    {
        echo __FUNCTION__ . "\n";
    }

    function findMember($id)
    {
        echo __FUNCTION__ . "\n";
        return '';
    }
}