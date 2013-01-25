
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
  
  def self.get_data(url)
  
    response = WS.http.request_get(url)
    
    json = ""
    json = response.read_body if response.kind_of?(Net::HTTPSuccess)
    
    data = nil
    data = JSON.parse(json) unless json == ""
    
    data
  end
  
  def self.put_data(url, json)
    response = WS.http.request_put(url, json)
    response
  end
end
  
  