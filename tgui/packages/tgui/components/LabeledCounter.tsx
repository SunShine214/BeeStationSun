import { Box, BoxProps, computeBoxProps } from './Box';
import { Flex } from './Flex';

type Props = {
  label: string;
  todisplay: number;
  maxdigits: number;
} & Partial<{ unit: string; decimal: number;}> &
  Partial<BoxProps>;

export const LabeledCounter = (props: Props) => {
  const {
    label = '',
    todisplay = 0,
    maxdigits = 4,
    fontSize = 12,
    decimal = 0,
    unit = '',
    ...rest
  } = props;
  let actually_displayed = "";

  if(Math.abs(todisplay) > 10 ** maxdigits || Math.abs(todisplay) < 10 ** -maxdigits) {
    actually_displayed = Math.abs(todisplay).toExponential(maxdigits) + (unit ? " " : "") + unit;
  } else if(Math.abs(todisplay) < 1) {
    actually_displayed = Number(Math.abs(todisplay).toFixed(decimal)) + (unit ? " " : "") + unit;
  } else {
    actually_displayed = Math.abs(todisplay).toFixed(decimal) + (unit ? " " : "") + unit;
  }

  return (
    <Box {...computeBoxProps(rest)} inline>
      <Flex direction="column" align="center" inline>
        <Flex.Item>
          <Box textAlign="center" fontSize={fontSize} px={1}>
            {label}
          </Box>
        </Flex.Item>
        <Flex.Item>
          <Box
            backgroundColor="grey"
            width={`${Math.max(actually_displayed.length + 1, maxdigits + 1 + unit.length)}ch`}
            fontSize={fontSize}
            mx={1}
            px={1}
          >
            <Flex direction="row">
              {todisplay < 0 ? '-' : ''}
              <Box width="100%" textAlign="right">
                {actually_displayed}
              </Box>
            </Flex>
          </Box>
        </Flex.Item>
      </Flex>
    </Box>
  );
};
