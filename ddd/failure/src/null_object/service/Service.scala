package null_object.service

import domain.{Age, ContractRepository, UserName}
import null_object.domain.{ValidContract, Contract, ContractFactory}

object Service {
  def apply(userName: UserName, age: Age): Contract = {
    val contract: Contract = ContractFactory.create(userName, age)

    if (contract.isValid) {
      ContractRepository.apply(contract.asInstanceOf[ValidContract]) // castが必要
    }

    contract // API層でinvalidだった場合に「契約の作成に失敗しました」とする感じ　Factoryが理由を返せないため
  }
}
