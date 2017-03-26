package domain

case class Age(value: Int) {
  def isValid: Boolean = value >= 20
}
