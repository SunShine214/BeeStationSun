import { Component } from 'react';

import { Box } from './Box';
import { Chart } from './Chart';

export class Graph extends Component {
  constructor(props) {
    super(props);
    const {
      funct,
      upperLimit,
      lowerLimit,
      leftLimit,
      rightLimit,
      steps,
      ...rest
    } = props;
    this.distPerStep = (rightLimit - leftLimit) / steps;
  }

  iterateOverNodes(funct, leftLimit, steps) {
    let points = [];
    for(let i = 0; i <= steps; i++) {
      let xPos = (i * this.distPerStep + leftLimit);
      points.push([xPos, funct(xPos).toFixed(5)]);
    }
    return points;
  }

  render() {
    const {
    funct,
    upperLimit,
    lowerLimit,
    leftLimit,
    rightLimit,
    steps,
  } = this.props;
  return (
    <Box>
      <Chart.Line
              data={this.iterateOverNodes(funct, leftLimit, steps)}
              rangeX={[leftLimit, rightLimit]}
              rangeY={[lowerLimit, upperLimit]}
              strokeColor="rgba(0, 181, 173, 1)"
              fillColor="rgba(0, 181, 173, 0.25)"
            />
    </Box>
  );
  }
}
