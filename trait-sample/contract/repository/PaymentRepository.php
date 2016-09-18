<?php

namespace repository;


trait PaymentRepository
{
    function payContractCharge($member, $paymentMethod)
    {
        echo __FUNCTION__ . "\n";
    }

    function payPlanFee($member, $paymentMethod, $plan)
    {
        echo __FUNCTION__ . "\n";
    }
}