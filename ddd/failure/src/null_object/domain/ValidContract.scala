package null_object.domain

import domain.{Age, Status, UserName}

case class ValidContract(userName: UserName, age: Age, status: Status) extends Contract {
  override def isValid: Boolean = true
}

