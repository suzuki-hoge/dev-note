package exception.service

import domain.{Age, Contract, ContractRepository, UserName}
import exception.domain.ContractFactory

object Service {
  def apply(userName: UserName, age: Age): Contract = {
    val contract: Contract = ContractFactory.create(userName, age) // 例外は業務上発生しない

    ContractRepository.apply(contract)

    contract
  }
}
