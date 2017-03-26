package null_object.domain

trait Contract {
  def isValid: Boolean

  def getLetterForError(): String
}
