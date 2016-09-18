<?php

namespace repository;


trait PaymentMethodRepository
{
    function savePaymentMethod($paymentMethod)
    {
        echo __FUNCTION__ . "\n";
    }

    function findPaymentMethod($id)
    {
        echo __FUNCTION__ . "\n";
        return '';
    }
}