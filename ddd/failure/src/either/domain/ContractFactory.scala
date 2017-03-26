package either.domain

import domain.{Age, Contract, Status, UserName}

object ContractFactory {
  def create(userName: UserName, age: Age): Either[FailureReason, Contract] = {
    if (age.isValid) {
      Right(Contract(userName, age, Status(1)))
    } else {
      Left(FailureReason("不正な年齢です"))
    }
  }
}
