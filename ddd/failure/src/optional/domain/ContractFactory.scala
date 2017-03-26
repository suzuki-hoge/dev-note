package optional.domain

import domain.{Age, Contract, Status, UserName}

object ContractFactory {
  def create(userName: UserName, age: Age): Option[Contract] = {
    if (age.isValid) {
      Some(Contract(userName, age, Status(1)))
    } else {
      None
    }
  }
}
