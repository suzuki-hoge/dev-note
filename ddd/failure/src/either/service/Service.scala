package either.service

import domain.{Age, Contract, ContractRepository, UserName}
import either.domain.{ContractFactory, FailureReason}

object Service {
  def apply(userName: UserName, age: Age): Either[FailureReason, Contract] = {
    val contract: Either[FailureReason, Contract] = ContractFactory.create(userName, age)

    contract.right.map(ContractRepository.apply)

    contract
  }
}
