function note_start() {
  git checkout -B $1
  mkdir -p $1
  cd $1
}
