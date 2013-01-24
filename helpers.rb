
class Debug
  def self.alert(text)
    m = Qt::MessageBox.new()
    m.text = text
    m.exec()
  end
  
  def self.okCancel(text)
    m = Qt::MessageBox.new(Qt::MessageBox::Question, "Confirm", text, Qt::MessageBox::Cancel | Qt::MessageBox::Ok  )
    m.exec()
  end
  
  def self.yesNoCancel(text)
    m = Qt::MessageBox.new(Qt::MessageBox::Question, "Confirm", text, Qt::MessageBox::Cancel | Qt::MessageBox::No | Qt::MessageBox::Yes)
    m.exec()
  end

end

class WS
  def self.encode(uri)
    URI.encode(uri).gsub('/', '%2F')
  end
  
  def self.http
    Net::HTTP.new("localhost", 4567)
  end
end
  