function note_start() {
  git checkout -b $1
  mkdir $1
  cd $1
}
