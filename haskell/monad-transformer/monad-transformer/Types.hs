module Types where

type MailBody = String
type Address = String
type HospitalName = String
type Prescription = String
type Medicine = String
type Temperature = Double
type Time = String
type TemperatureLog = String
data Health = Good | Taking | Bad deriving (Eq, Show)
type Message = String
