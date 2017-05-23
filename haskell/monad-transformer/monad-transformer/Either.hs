module Either where

import Types

goHospital :: HospitalName -> Either String Prescription
goHospital name = Right "prescription"

getMedicine :: Prescription -> Either String Medicine
getMedicine prescription = Right "medicine"

goHospital' :: HospitalName -> Either String Prescription
goHospital' name = Left "dont need"
