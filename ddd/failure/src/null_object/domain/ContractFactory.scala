package null_object.domain

import domain.{Age, Status, UserName}

object ContractFactory {
  def create(userName: UserName, age: Age): Contract = {
    if (age.isValid) {
      ValidContract(userName, age, Status(1))
    } else {
      InvalidContract()
    }
  }
}
