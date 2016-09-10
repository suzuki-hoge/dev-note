<?php

namespace repository;


trait PlanRepository {
    function savePlan($plan) {
        echo __FUNCTION__ . "\n";
    }

    function findPlan($id) {
        echo __FUNCTION__ . "\n";
        return '';
    }
}