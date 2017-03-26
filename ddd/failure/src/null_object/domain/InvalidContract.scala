package null_object.domain

case class InvalidContract() extends Contract {
  override def isValid: Boolean = false

  override def getLetterForError():String = {
    "契約の作成に失敗しました"
  }
}
