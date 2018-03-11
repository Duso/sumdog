require 'socket'
require 'cgi'
require 'json'

RESULT_FILE = 'results.json'

# takes the input parameters
# returns and error code and the parsed input parameters
def check_input(arg1, arg2)
    error = 0
    min = arg1.to_i
    max = arg2.to_i

    # check if range was not integers
    if min == 0 && arg1 != '0'
        return -1, 0, 0
    elsif max ==0 && arg2 != '0'
        return -1, 0, 0
    end

    # check for correct range
    if min < 0 || max > 1000000
        return -1, 0, 0
    end

    # if range was specified in the wrong order
    if min > max
        min, max = max, min
    end

    return error, min, max
end

# wrong answers should be > 0, different from the correct answer 
# and different from eachother
def gen_wrong_answers(correct)
   
    wrong = []
    for i in 0..2
        flag = 1
        wr = 0
        while flag == 1
            wr = rand(correct-5..correct+5)
            if wr > 0 && wr != correct && !wrong.include?(wr)
                flag = 0
            end
        end
        wrong.push(wr)
    end

    return wrong
end

# generates question and writes to .json file
def math(arg1, arg2)
    
    # check the input parameters
    error, min, max = check_input(arg1, arg2)
    if error != 0
        return -1
    end

    # generate question, correct and wrong answers
    answer = rand(min..max)
    first = rand(0..answer)
    second = answer - first
    wrong = gen_wrong_answers(answer)
    
    # store everything in a hash
    data = {}
    data["question"] = "#{first} + #{second}"
    data["answer"] = answer
    data["wrong1"] = wrong[0]
    data["wrong2"] = wrong[1]
    data["wrong3"] = wrong[2]

    File.write(RESULT_FILE, data.to_json)
    
    return 0
end


server = TCPServer.new('localhost', 1234)
loop do

    socket = server.accept
    request = socket.gets

    STDERR.puts request

    # extract range from url parameters
    request_uri = request.split(" ")[1]
    params = CGI.parse(request_uri.split("?").last)

    ret = math(params['min'][0], params['max'][0])

    if ret == -1
        msg = "Incorrect range. Please provide a range between 0 and 1000000"

        socket.print "HTTP/1.1 500 Internal Server Error\r\n" +
                     "Content-Type: text/plain\r\n" +
                     "Content-Length: #{msg.size}\r\n" +
                     "Connection: close\r\n"
        socket.print "\r\n"
        socket.print msg
    else
        socket.print "HTTP/1.1 200 OK\r\n" +
                    "Content-Type: application/json\r\n" +
                    "Content-Length: #{File.size(RESULT_FILE)}\r\n" +
                    "Connection: close\r\n"
        socket.print "\r\n"
        # write file to socket
        IO.copy_stream(RESULT_FILE, socket)
    end
    
    socket.close
end