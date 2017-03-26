package domain

object ContractFactory {
  def create(userName: UserName, age: Age): Contract = {
    if (age.isValid) {
      Contract(userName, age, Status(1))
    } else {
      ???
    }
  }
}
