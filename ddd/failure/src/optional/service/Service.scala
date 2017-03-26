package optional.service

import domain.{Age, Contract, ContractRepository, UserName}
import optional.domain.ContractFactory

object Service {
  def apply(userName: UserName, age: Age): Option[Contract] = {
    val contract: Option[Contract] = ContractFactory.create(userName, age)

    contract.foreach(
      ContractRepository.apply
    )

    contract // API層でnoneだった場合に「契約の作成に失敗しました」とする感じ　Factoryが理由を返せないため
  }
}
