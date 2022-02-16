#mcandrew

from interface import interface
from model import VAR

if __name__ == "__main__":
    
    io = interface(0)
    predictions = io.grab_recent_predictions()
