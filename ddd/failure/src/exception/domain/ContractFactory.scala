package exception.domain

import domain.{Age, Contract, Status, UserName}

object ContractFactory {
  def create(userName: UserName, age: Age): Contract = {
    if (age.isValid) {
      Contract(userName, age, Status(1))
    } else {
      throw new RuntimeException("不正な年齢です")
    }
  }
}
